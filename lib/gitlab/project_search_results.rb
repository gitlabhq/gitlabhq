module Gitlab
  class ProjectSearchResults < SearchResults
    attr_reader :project, :repository_ref

    def initialize(current_user, project, query, repository_ref = nil)
      @current_user = current_user
      @project = project
      @repository_ref = repository_ref.presence || project.default_branch
      @query = query
    end

    def objects(scope, page = nil)
      case scope
      when 'notes'
        notes.page(page).per(per_page)
      when 'blobs'
        Kaminari.paginate_array(blobs).page(page).per(per_page)
      when 'wiki_blobs'
        Kaminari.paginate_array(wiki_blobs).page(page).per(per_page)
      when 'commits'
        Kaminari.paginate_array(commits).page(page).per(per_page)
      else
        super
      end
    end

    def blobs_count
      @blobs_count ||= blobs.count
    end

    def notes_count
      @notes_count ||= notes.count
    end

    def wiki_blobs_count
      @wiki_blobs_count ||= wiki_blobs.count
    end

    def commits_count
      @commits_count ||= commits.count
    end

    def self.parse_search_result(result)
      ref = nil
      filename = nil
      basename = nil
      startline = 0

      result.each_line.each_with_index do |line, index|
        if line =~ /^.*:.*:\d+:/
          ref, filename, startline = line.split(':')
          startline = startline.to_i - index
          extname = Regexp.escape(File.extname(filename))
          basename = filename.sub(/#{extname}$/, '')
          break
        end
      end

      data = ""

      result.each_line do |line|
        data << line.sub(ref, '').sub(filename, '').sub(/^:-\d+-/, '').sub(/^::\d+:/, '')
      end

      OpenStruct.new(
        filename: filename,
        basename: basename,
        ref: ref,
        startline: startline,
        data: data
      )
    end

    private

    def blobs
      @blobs ||= begin
        blobs = project.repository.search_files_by_content(query, repository_ref).first(100)
        found_file_names = Set.new

        results = blobs.map do |blob|
          blob = self.class.parse_search_result(blob)
          found_file_names << blob.filename

          [blob.filename, blob]
        end

        project.repository.search_files_by_name(query, repository_ref).first(100).each do |filename|
          results << [filename, nil] unless found_file_names.include?(filename)
        end

        results.sort_by(&:first)
      end
    end

    def wiki_blobs
      @wiki_blobs ||= begin
        if project.wiki_enabled? && query.present?
          project_wiki = ProjectWiki.new(project)

          unless project_wiki.empty?
            project_wiki.search_files(query)
          else
            []
          end
        else
          []
        end
      end
    end

    def notes
      @notes ||= project.notes.user.search(query, as_user: @current_user).order('updated_at DESC')
    end

    def commits
      @commits ||= project.repository.find_commits_by_message(query)
    end

    def project_ids_relation
      project
    end
  end
end
