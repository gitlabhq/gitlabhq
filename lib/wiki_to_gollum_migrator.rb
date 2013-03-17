class WikiToGollumMigrator

  attr_reader :projects

  def initialize
    @projects = []

    Project.find_in_batches(batch_size: 50) do |batch|
      batch.each { |p| @projects << p if p.wikis.any? }
    end
  end

  def migrate!
    projects.each do |project|
      log "\nMigrating Wiki for '#{project.path_with_namespace}'"
      wiki = create_gollum_repo(project)
      create_pages project, wiki
      log "Project '#{project.path_with_namespace}' migrated. " + "[OK]".green
    end
  end

  def rollback!
    log "\nBeginning Wiki Migration Rollback..."
    projects.each do |project|
      destroy_gollum_repo project
    end
    log "\nWiki Rollback Complete."
  end

  private

  def create_gollum_repo(project)
    GollumWiki.new(project, nil).wiki
  end

  def destroy_gollum_repo(project)
    log "  Removing Wiki repo for project: #{project.path_with_namespace}"
    path = GollumWiki.new(project, nil).path_with_namespace
    if Gitlab::Shell.new.remove_repository(path)
      log "  Wiki destroyed successfully. " + "[OK}".green
    else
      log "  Problem destroying wiki. Please remove it manually. " + "[FAILED]".red
    end
  end

  def create_pages(project, wiki)
    pages = project.wikis.group(:slug).all

    pages.each do |page|
      create_page_and_revisions(project, page)
    end
  end

  def create_page_and_revisions(project, page)
    # Grab all revisions of the page
    revisions = project.wikis.where(slug: page.slug).ordered.all

    # Remove the first revision created from the array
    # and use it to create the Gollum page. Each successive revision
    # will then be applied to the new Gollum page as an update.
    first_rev = revisions.pop

    wiki = GollumWiki.new(project, page.user)
    wiki_page = WikiPage.new(wiki)

    attributes = extract_attributes_from_page(first_rev, project)

    log "  Creating page '#{first_rev.title}'..."
    if wiki_page.create(attributes)
      log "  Created page '#{wiki_page.title}' " + "[OK]".green

      # Reverse the revisions to create them in the correct
      # chronological order.
      create_revisions(project, wiki_page, revisions.reverse)
    else
      log "  Failed to create page '#{wiki_page.title}' " + "[FAILED]".red
    end
  end

  def create_revisions(project, page, revisions)
    log "    Creating revisions..."
    revisions.each do |revision|
      # Reinitialize a new GollumWiki instance for each page
      # and revision created so the correct User is shown in
      # the commit message.
      wiki = GollumWiki.new(project, revision.user)
      wiki_page = wiki.find_page(page.slug)

      attributes = extract_attributes_from_page(revision, project)

      content = attributes[:content]

      if wiki_page.update(content)
        log "    Created revision " + "[OK]".green
      else
        log "    Failed to create revision " + "[FAILED]".red
      end
    end
  end

  def extract_attributes_from_page(page, project)
    attributes = page.attributes
                     .with_indifferent_access
                     .slice(:title, :content)

    slug = page.slug

    # Change 'index' pages to 'home' pages to match Gollum standards
    if slug.downcase == "index"
      attributes[:title] = "home" unless home_already_exists?(project)
    end

    attributes
  end

  def home_already_exists?(project)
    project.wikis.where(slug: 'home').any? || project.wikis.where(slug: 'Home').any?
  end

  def log(message)
    puts message
  end

end
