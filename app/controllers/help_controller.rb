class HelpController < ApplicationController
  def index
  end

  def show
    @category = clean_path_info(params[:category])
    @file = clean_path_info(params[:file])

    if File.exists?(Rails.root.join('doc', @category, @file + '.md'))
      render 'show'
    else
      not_found!
    end
  end

  def shortcuts
  end

  def ui
  end

  private

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
