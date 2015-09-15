class HelpController < ApplicationController
  skip_before_action :authenticate_user!, :reject_blocked

  layout 'help'

  def index
  end

  def show
    @category = clean_path_info(path_params[:category])
    @file = path_params[:file]

    respond_to do |format|
      format.any(:markdown, :md, :html) do
        # Note: We are purposefully NOT using `Rails.root.join`
        path = File.join(Rails.root, 'doc', @category, "#{@file}.md")

        if File.exist?(path)
          @markdown = File.read(path)

          render 'show.html.haml'
        else
          # Force template to Haml
          render 'errors/not_found.html.haml', layout: 'errors', status: 404
        end
      end

      # Allow access to images in the doc folder
      format.any(:png, :gif, :jpeg) do
        # Note: We are purposefully NOT using `Rails.root.join`
        path = File.join(Rails.root, 'doc', @category, "#{@file}.#{params[:format]}")

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

  def ui
  end

  private

  def path_params
    params.require(:category)
    params.require(:file)

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
