return if Rails.env.production?

require 'png_quantizator'
require 'parallel'

# The amount of variance (in bytes) allowed in
# file size when testing for compression size
TOLERANCE = 10

namespace :pngquant do
  # Returns an array of all images eligible for compression
  def doc_images
    Dir.glob('doc/**/*.png', File::FNM_CASEFOLD)
  end

  # Runs pngquant on an image and optionally
  # writes the result to disk
  def compress_image(file, overwrite_original)
    compressed_file = "#{file}.compressed"
    FileUtils.copy(file, compressed_file)

    pngquant_file = PngQuantizator::Image.new(compressed_file)

    # Run the image repeatedly through pngquant until
    # the change in file size is within TOLERANCE
    loop do
      before = File.size(compressed_file)
      pngquant_file.quantize!
      after = File.size(compressed_file)
      break if before - after <= TOLERANCE
    end

    savings = File.size(file) - File.size(compressed_file)
    is_uncompressed = savings > TOLERANCE

    if is_uncompressed && overwrite_original
      FileUtils.copy(compressed_file, file)
    end

    FileUtils.remove(compressed_file)

    [is_uncompressed, savings]
  end

  # Ensures pngquant is available and prints an error if not
  def check_executable
    unless system('pngquant --version', out: File::NULL)
      warn(
        'Error: pngquant executable was not detected in the system.'.color(:red),
        'Download pngquant at https://pngquant.org/ and place the executable in /usr/local/bin'.color(:green)
      )
      abort
    end
  end

  desc 'GitLab | pngquant | Compress all documentation PNG images using pngquant'
  task :compress do
    check_executable

    files = doc_images
    puts "Compressing #{files.size} PNG files in doc/**"

    Parallel.each(files) do |file|
      was_uncompressed, savings = compress_image(file, true)

      if was_uncompressed
        puts "#{file} was reduced by #{savings} bytes"
      end
    end
  end

  desc 'GitLab | pngquant | Checks that all documentation PNG images have been compressed with pngquant'
  task :lint do
    check_executable

    files = doc_images
    puts "Checking #{files.size} PNG files in doc/**"

    uncompressed_files = Parallel.map(files) do |file|
      is_uncompressed, _ = compress_image(file, false)
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
