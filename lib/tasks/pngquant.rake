return if Rails.env.production?

require 'png_quantizator'
require 'parallel'
require_relative '../../tooling/lib/tooling/images'

# The amount of variance (in bytes) allowed in
# file size when testing for compression size

namespace :pngquant do
  # Returns an array of all images eligible for compression
  def doc_images
    Dir.glob('doc/**/*.png', File::FNM_CASEFOLD)
  end

  desc 'GitLab | Pngquant | Compress all documentation PNG images using pngquant'
  task :compress do
    files = doc_images
    puts "Compressing #{files.size} PNG files in doc/**"

    Parallel.each(files) do |file|
      was_uncompressed, savings = Tooling::Image.compress_image(file)

      if was_uncompressed
        puts "#{file} was reduced by #{savings} bytes"
      end
    end
  end

  desc 'GitLab | Pngquant | Checks that all documentation PNG images have been compressed with pngquant'
  task :lint do
    files = doc_images
    puts "Checking #{files.size} PNG files in doc/**"

    uncompressed_files = Parallel.map(files) do |file|
      is_uncompressed, _ = Tooling::Image.compress_image(file, true)
      if is_uncompressed
        puts "Uncompressed file detected: ".color(:red) + file
        file
      end
    end.compact

    if uncompressed_files.empty?
      puts "All documentation images are optimally compressed!".color(:green)
    else
      warn(
        "The #{uncompressed_files.size} image(s) above have not been optimally compressed using pngquant.".color(:red),
        'Please run "bin/rake pngquant:compress" and commit the result.'
      )
      abort
    end
  end
end
