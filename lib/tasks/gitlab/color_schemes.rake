# frozen_string_literal: true

# Regenerates the syntax-highlighting scheme preview thumbnails shown in user
# preferences (app/assets/images/<scheme>-scheme-preview.png).
#
# Rendering logic lives in Tooling::ColorSchemes::PreviewGenerator (covered by
# specs). This task wraps it: it writes each scheme's HTML, screenshots it with
# headless Chrome, and optimizes the PNG with pngquant.
#
# Usage:
#   bundle exec rake gitlab:color_schemes:preview_images
#   CHROME_BIN=/usr/bin/chromium bundle exec rake gitlab:color_schemes:preview_images
#
# Requirements: a headless Chrome/Chromium binary on PATH or via CHROME_BIN, and
# pngquant for optimization (the task warns and skips optimization without it).
namespace :gitlab do
  namespace :color_schemes do
    desc 'GitLab | Color schemes | Regenerate syntax highlighting preview thumbnails'
    task :preview_images do
      require 'tmpdir'
      require 'open3'
      require 'png_quantizator'
      require_relative '../../../tooling/lib/tooling/color_schemes/preview_generator'

      root = File.expand_path('../../..', __dir__)
      generator = Tooling::ColorSchemes::PreviewGenerator.new(root: root)

      on_path = ->(bin) do
        ENV['PATH'].to_s.split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, bin)) }
      end
      chrome = ENV['CHROME_BIN'] || %w[google-chrome google-chrome-stable chromium chromium-browser].find(&on_path)
      raise 'No Chrome/Chromium found. Set CHROME_BIN to a headless Chrome binary.' unless chrome

      gen = Tooling::ColorSchemes::PreviewGenerator
      window = "#{gen::WIDTH},#{gen::HEIGHT}"

      screenshot = ->(html_path, png_path, scale) do
        # --no-sandbox lets the task run as root in CI/Docker; the HTML is local and trusted.
        cmd = [
          chrome, '--headless=new', '--disable-gpu', '--no-sandbox', '--hide-scrollbars',
          "--force-device-scale-factor=#{scale}", "--window-size=#{window}",
          "--screenshot=#{png_path}", "file://#{html_path}"
        ]
        output, status = Open3.capture2e(*cmd)
        raise "Chrome failed for #{html_path}:\n#{output}" unless status.success?
      end

      generator.schemes.each do |scheme|
        out = generator.output_path(scheme)

        Dir.mktmpdir do |dir|
          content_html = File.join(dir, "#{scheme}.html")
          big_png = File.join(dir, "#{scheme}@2x.png")
          File.write(content_html, generator.html_for(scheme))
          # Render at SUPERSAMPLE scale, then let Chrome downscale the image to the
          # final size so the text edges come out smooth.
          screenshot.call(content_html, big_png, gen::SUPERSAMPLE)

          down_html = File.join(dir, "#{scheme}-down.html")
          File.write(down_html, generator.downscale_html("file://#{big_png}"))
          screenshot.call(down_html, out, 1)
        end

        # Headless Chrome writes an unoptimized PNG. Quantize it with pngquant
        # (the same tool used for other image assets) so the thumbnails stay
        # small. Skip quietly if pngquant is not installed.
        begin
          image = PngQuantizator::Image.new(out)
          1000.times do
            before = File.size(out)
            image.quantize!
            break if before - File.size(out) <= 100
          end
        rescue PngQuantizator::PngQuantError => e
          warn "Skipped PNG optimization for #{scheme}: #{e.message} (install pngquant to enable)"
        end

        puts "Generated #{out} (#{File.size(out)} bytes)"
      end
    end
  end
end
