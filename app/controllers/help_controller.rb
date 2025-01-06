# frozen_string_literal: true

class HelpController < ApplicationController
  skip_before_action :authenticate_user!, unless: :public_visibility_restricted?
  skip_before_action :check_two_factor_requirement
  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  layout 'help'

  # Taken from Jekyll
  # https://github.com/jekyll/jekyll/blob/3.5-stable/lib/jekyll/document.rb#L13
  YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m

  def index
    @help_index = markdown_for(path_to_doc('index.md'))

    # Prefix Markdown links with `help/` unless they are external links.
    # '//' not necessarily part of URL, e.g., mailto:mail@example.com
    # See https://rubular.com/r/DFHZl5w8d3bpzV
    @help_index.gsub!(%r{(?<delim>\]\()(?!\w+:)(?!/)(?<link>[^\)\(]+\))}) do
      "#{$~[:delim]}#{Gitlab.config.gitlab.relative_url_root}/help/#{$~[:link]}"
    end
  end

  def show
    @path = Rack::Utils.clean_path_info(params[:path])

    respond_to do |format|
      format.any(:markdown, :md, :html) do
        if redirect_to_documentation_website?
          redirect_to documentation_url
        else
          render_documentation
        end
      end

      # Allow access to specific media files in the doc folder
      format.any(:png, :gif, :jpeg, :mp4, :mp3) do
        # Note: We are purposefully NOT using `Rails.root.join` because of https://gitlab.com/gitlab-org/gitlab/-/issues/216028.
        path = path_to_doc("#{@path}.#{params[:format]}")

        if File.exist?(path)
          send_file(path, disposition: 'inline')
        else
          head :not_found
        end
      end

      # Any other format we don't recognize, just respond 404
      format.any { head :not_found }
    end
  end

  def redirect_to_docs
    redirect_to documentation_base_url || Gitlab::Saas.doc_url
  end

  def shortcuts; end

  def instance_configuration
    @instance_configuration = InstanceConfiguration.new
  end

  def drawers
    @clean_path = Rack::Utils.clean_path_info(params[:markdown_file])
    @path = path_to_doc("#{@clean_path}.md")

    if File.exist?(@path)
      render :drawers, formats: :html, layout: false
    else
      head :not_found
    end
  end

  private

  # Remove YAML frontmatter so that it doesn't look weird
  helper_method :get_markdown_without_frontmatter
  def get_markdown_without_frontmatter(path)
    markdown = File.read(path)
    markdown_title_matches = markdown.match(/^title: (?<title>.+)$/)

    without_frontmatter = markdown.sub(YAML_FRONT_MATTER_REGEXP, '')

    if markdown_title_matches
      "# #{markdown_title_matches[:title]}\n\n#{without_frontmatter}"
    else
      without_frontmatter
    end
  end

  def redirect_to_documentation_website?
    Gitlab::UrlSanitizer.valid_web?(documentation_url)
  end

  def documentation_url
    return unless documentation_base_url

    @documentation_url ||= Gitlab::Utils.append_path(documentation_base_url, documentation_file_path)
  end

  def documentation_base_url
    @documentation_base_url ||= documentation_base_url_from_yml_configuration || documentation_base_url_from_db
  end

  # DEPRECATED
  def documentation_base_url_from_db
    Gitlab::CurrentSettings.current_application_settings.help_page_documentation_base_url.presence
  end

  def documentation_base_url_from_yml_configuration
    ::Gitlab.config.gitlab_docs.host.presence if ::Gitlab.config.gitlab_docs.enabled
  end

  def documentation_file_path
    @documentation_file_path ||= [version_segment, 'ee', "#{@path}.html"].compact.join('/')
  end

  def version_segment
    return if Gitlab.pre_release?

    version = Gitlab.version_info
    [version.major, version.minor].join('.')
  end

  def render_documentation
    # Note: We are purposefully NOT using `Rails.root.join` because of https://gitlab.com/gitlab-org/gitlab/-/issues/216028.
    path = path_to_doc("#{@path}.md")

    @markdown = markdown_for(path)

    if @markdown
      render :show, formats: :html
    else
      # Force template to Haml
      render 'errors/not_found', layout: 'errors', status: :not_found, formats: :html
    end
  end

  def path_to_doc(file_name)
    File.join(Rails.root, 'doc', file_name)
  end

  def markdown_for(raw_path)
    if File.exist?(raw_path)
      path = raw_path
    elsif raw_path.ends_with?('index.md')
      munged_path = raw_path.gsub('index.md', '_index.md')
      path = munged_path if File.exist?(munged_path)
    end

    return unless path

    content = get_markdown_without_frontmatter(path)
    Gitlab::Help::HugoTransformer.new.transform(content)
  end
end

::HelpController.prepend_mod
