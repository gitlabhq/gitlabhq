class HelpController < ApplicationController
  skip_before_action :authenticate_user!

  layout 'help'

  # Taken from Jekyll
  # https://github.com/jekyll/jekyll/blob/3.5-stable/lib/jekyll/document.rb#L13
  YAML_FRONT_MATTER_REGEXP = /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m

  def index
    # Remove YAML frontmatter so that it doesn't look weird
    @help_index = File.read(Rails.root.join('doc', 'README.md')).sub(YAML_FRONT_MATTER_REGEXP, '')

    # Prefix Markdown links with `help/` unless they are external links
    # See http://rubular.com/r/X3baHTbPO2
    @help_index.gsub!(%r{(?<delim>\]\()(?!.+://)(?!/)(?<link>[^\)\(]+\))}) do
      "#{$~[:delim]}#{Gitlab.config.gitlab.relative_url_root}/help/#{$~[:link]}"
    end
  end

  def show
    @path = clean_path_info(path_params[:path])

    respond_to do |format|
      format.any(:markdown, :md, :html) do
        # Note: We are purposefully NOT using `Rails.root.join`
        path = File.join(Rails.root, 'doc', "#{@path}.md")

        if File.exist?(path)
          # Remove YAML frontmatter so that it doesn't look weird
          @markdown = File.read(path).gsub(YAML_FRONT_MATTER_REGEXP, '')

          render 'show.html.haml'
        else
          # Force template to Haml
          render 'errors/not_found.html.haml', layout: 'errors', status: 404
        end
      end

      # Allow access to images in the doc folder
      format.any(:png, :gif, :jpeg, :mp4) do
        # Note: We are purposefully NOT using `Rails.root.join`
        path = File.join(Rails.root, 'doc', "#{@path}.#{params[:format]}")

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

  def shortcuts
  end

  def instance_configuration
    @instance_configuration = InstanceConfiguration.new
  end

  def ui
    @user = User.new(id: 0, name: 'John Doe', username: '@johndoe')
  end

  private

  def path_params
    params.require(:path)

    params
  end

  PATH_SEPS = Regexp.union(*[::File::SEPARATOR, ::File::ALT_SEPARATOR].compact)

  # Taken from ActionDispatch::FileHandler
  # Cleans up the path, to prevent directory traversal outside the doc folder.
  def clean_path_info(path_info)
    parts = path_info.split(PATH_SEPS)

    clean = []

    # Walk over each part of the path
    parts.each do |part|
      # Turn `one//two` or `one/./two` into `one/two`.
      next if part.empty? || part == '.'

      if part == '..'
        # Turn `one/two/../` into `one`
        clean.pop
      else
        # Add simple folder names to the clean path.
        clean << part
      end
    end

    # If the path was an absolute path (i.e. `/` or `/one/two`),
    # add `/` to the front of the clean path.
    clean.unshift '/' if parts.empty? || parts.first.empty?

    # Join all the clean path parts by the path separator.
    ::File.join(*clean)
  end
end
