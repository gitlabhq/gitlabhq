# This task will generate a standard and Retina sprite of all of the current
# Gemojione Emojis, with the accompanying SCSS map.
#
# It will not appear in `rake -T` output, and the dependent gems are not
# included in the Gemfile by default, because this task will only be needed
# occasionally, such as when new Emojis are added to Gemojione.

begin
  require 'sprite_factory'
  require 'rmagick'
rescue LoadError
  # noop
end

namespace :gemojione do
  task sprite: :environment do
    check_requirements!

    SIZE   = 20
    RETINA = SIZE * 2

    Dir.mktmpdir do |tmpdir|
      # Copy the Gemojione assets to the temporary folder for resizing
      FileUtils.cp_r(Gemojione.index.images_path, tmpdir)

      Dir.chdir(tmpdir) do
        Dir["**/*.png"].each do |png|
          resize!(File.join(tmpdir, png), SIZE)
        end
      end

      style_path = Rails.root.join(*%w(app assets stylesheets pages emojis.scss))

      # Combine the resized assets into a packed sprite and re-generate the SCSS
      SpriteFactory.cssurl = "image-url('$IMAGE')"
      SpriteFactory.run!(File.join(tmpdir, 'images'), {
        output_style: style_path,
        output_image: "app/assets/images/emoji.png",
        selector:     '.emoji-',
        style:        :scss,
        nocomments:   true,
        pngcrush:     true,
        layout:       :packed
      })

      # SpriteFactory's SCSS is a bit too verbose for our purposes here, so
      # let's simplify it
      system(%Q(sed -i '' "s/width: #{SIZE}px; height: #{SIZE}px; background: image-url('emoji.png')/background-position:/" #{style_path}))
      system(%Q(sed -i '' "s/ no-repeat//" #{style_path}))

      # Append a generic rule that applies to all Emojis
      File.open(style_path, 'a') do |f|
        f.puts
        f.puts <<-CSS.strip_heredoc
        .emoji-icon {
          background-image: image-url('emoji.png');
          background-repeat: no-repeat;
          height: #{SIZE}px;
          width: #{SIZE}px;

          @media only screen and (-webkit-min-device-pixel-ratio: 2),
                 only screen and (min--moz-device-pixel-ratio: 2),
                 only screen and (-o-min-device-pixel-ratio: 2/1),
                 only screen and (min-device-pixel-ratio: 2),
                 only screen and (min-resolution: 192dpi),
                 only screen and (min-resolution: 2dppx) {
            background-image: image-url('emoji@2x.png');
            background-size: 840px 820px;
          }
        }
        CSS
      end
    end

    # Now do it again but for Retina
    Dir.mktmpdir do |tmpdir|
      # Copy the Gemojione assets to the temporary folder for resizing
      FileUtils.cp_r(Gemojione.index.images_path, tmpdir)

      Dir.chdir(tmpdir) do
        Dir["**/*.png"].each do |png|
          resize!(File.join(tmpdir, png), RETINA)
        end
      end

      # Combine the resized assets into a packed sprite and re-generate the SCSS
      SpriteFactory.run!(File.join(tmpdir, 'images'), {
        output_image: "app/assets/images/emoji@2x.png",
        style:        false,
        nocomments:   true,
        pngcrush:     true,
        layout:       :packed
      })
    end
  end

  def check_requirements!
    return if defined?(SpriteFactory) && defined?(Magick)

    puts <<-MSG.strip_heredoc
      This task is disabled by default and should only be run when the Gemojione
      gem is updated with new Emojis.

      To enable this task, *temporarily* add the following lines to Gemfile and
      re-bundle:

      gem 'sprite-factory'
      gem 'rmagick'
    MSG

    exit 1
  end

  def resize!(image_path, size)
    # Resize the image in-place, save it, and free the object
    image = Magick::Image.read(image_path).first
    image.resize!(size, size)
    image.write(image_path) { self.quality = 100 }
    image.destroy!
  end
end
