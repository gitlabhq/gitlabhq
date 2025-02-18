# frozen_string_literal: true

namespace :tanuki_emoji do
  desc 'Generates Emoji aliases fixtures'
  task aliases: :environment do
    ALLOWED_ALIASES = [':)', ':('].freeze
    aliases = {}

    TanukiEmoji.index.all.find_each do |emoji|
      emoji.aliases.each do |emoji_alias|
        aliases[TanukiEmoji::Character.format_name(emoji_alias)] = emoji.name
      end

      emoji.ascii_aliases.intersection(ALLOWED_ALIASES).each do |ascii_alias|
        # We add an extra space at the end so that when a user types ":) "
        # we'd still match this alias and not show "cocos (keeling) islands" as the first result.
        # The initial ":" is ignored when matching because it's our emoji prefix in Markdown.
        aliases[ascii_alias + ' '] = emoji.name
      end
    end

    aliases_json_file = File.join(Rails.root, 'fixtures', 'emojis', 'aliases.json')
    File.open(aliases_json_file, 'w') do |handle|
      handle.write(Gitlab::Json.pretty_generate(aliases, indent: '   ', space: '', space_before: ''))
    end
  end

  desc 'Generates Emoji SHA256 digests'
  task digests: :environment do
    require 'digest/sha2'

    digest_emoji_map = {}
    emojis_array = []

    TanukiEmoji.index.all.sort_by(&:sort_key).each do |emoji|
      emoji_path = Gitlab::Emoji.emoji_public_absolute_path.join("#{emoji.name}.png")

      digest_entry = {
        category: emoji.category,
        moji: emoji.codepoints,
        description: emoji.description,
        unicodeVersion: emoji.unicode_version,
        digest: Digest::SHA256.file(emoji_path).hexdigest
      }

      digest_emoji_map[emoji.name] = digest_entry

      # Our new map is only characters to make the json substantially smaller
      emoji_entry = {
        n: emoji.name,
        c: emoji.category,
        e: emoji.codepoints,
        d: emoji.description,
        u: emoji.unicode_version
      }

      emojis_array << emoji_entry
    end

    digests_json = File.join(Rails.root, 'fixtures', 'emojis', 'digests.json')
    File.open(digests_json, 'w') do |handle|
      handle.write(Gitlab::Json.pretty_generate(digest_emoji_map))
    end

    emojis_json = Gitlab::Emoji.emoji_public_absolute_path.join('emojis.json')
    File.open(emojis_json, 'w') do |handle|
      handle.write(Gitlab::Json.pretty_generate(emojis_array))
    end
  end

  desc 'Import emoji assets from TanukiEmoji to versioned folder'
  task import: :environment do
    require 'mini_magick'

    # Setting to the same size as previous gemojione images
    EMOJI_SIZE = 64

    emoji_dir = Gitlab::Emoji.emoji_public_absolute_path

    puts "Importing emojis into: #{emoji_dir} ..."

    # Re-create the assets folder and copy emojis renaming them to use name instead of unicode hex
    FileUtils.rm_rf(emoji_dir) if Dir.exist?(emoji_dir)
    FileUtils.mkdir_p(emoji_dir, mode: 0700)

    TanukiEmoji.index.all.find_each do |emoji|
      source = File.join(TanukiEmoji.images_path, emoji.image_name)
      destination = File.join(emoji_dir, "#{emoji.name}.png")

      FileUtils.cp(source, destination)
      resize!(destination, EMOJI_SIZE)
      print emoji.codepoints
    end

    puts
    puts 'Done!'
  end

  # This task will generate a standard and Retina sprite of all of the current
  # TanukiEmoji Emojis, with the accompanying SCSS map.
  #
  # It will not appear in `rake -T` output, and the dependent gems are not
  # included in the Gemfile by default, because this task will only be needed
  # occasionally, such as when new Emojis are added to TanukiEmoji.
  task sprite: :environment do
    begin
      require 'sprite_factory'
      # Sprite-Factory still requires rmagick, but maybe could be migrated to support minimagick
      # Upstream issue: https://github.com/jakesgordon/sprite-factory/issues/47#issuecomment-929302890
      require 'rmagick'
    rescue LoadError
      # noop
    end

    check_requirements!

    SIZE   = 20
    RETINA = SIZE * 2

    # Update these values to the width and height of the sprite sheet when
    # new emoji are added.
    SPRITESHEET_WIDTH = 1240
    SPRITESHEET_HEIGHT = 1220

    emoji_dir = Gitlab::Emoji.emoji_public_absolute_path

    puts "Preparing sprites for regular size: #{SIZE}px..."

    Dir.mktmpdir do |tmpdir|
      FileUtils.cp_r(File.join(emoji_dir, '.'), tmpdir)

      Dir.chdir(tmpdir) do
        Dir["**/*.png"].each do |png|
          tmp_image_path = File.join(tmpdir, png)
          resize!(tmp_image_path, SIZE)
          print '.'
        end
      end
      puts ' Done!'

      puts "\n"

      style_path = Rails.root.join(*%w[app assets stylesheets emoji_sprites.scss])

      print 'Compiling sprites regular sprites... '

      # Combine the resized assets into a packed sprite and re-generate the SCSS
      SpriteFactory.cssurl = "image-url('$IMAGE')"
      SpriteFactory.run!(tmpdir, {
        output_style: style_path,
        output_image: "app/assets/images/emoji.png",
        selector: '.emoji-',
        style: :scss,
        nocomments: true,
        pngcrush: true,
        layout: :packed
      })

      # SpriteFactory's SCSS is a bit too verbose for our purposes here, so
      # let's simplify it
      system(%(sed -i '' "s/width: #{SIZE}px; height: #{SIZE}px; background: image-url('emoji.png')/background-position:/" #{style_path}))
      system(%(sed -i '' "s/ no-repeat//" #{style_path}))
      system(%(sed -i '' "s/ 0px/ 0/g" #{style_path}))

      # Append a generic rule that applies to all Emojis
      File.open(style_path, 'a') do |f|
        f.puts
        f.puts <<-CSS.strip_heredoc
        .emoji-icon {
          background-image: image-url('emoji.png');
          background-repeat: no-repeat;
          color: transparent;
          text-indent: -99em;
          height: #{SIZE}px;
          width: #{SIZE}px;

          /* stylelint-disable media-feature-name-no-vendor-prefix */
          @media only screen and (-webkit-min-device-pixel-ratio: 2),
            only screen and (min--moz-device-pixel-ratio: 2),
            only screen and (-o-min-device-pixel-ratio: 2/1),
            only screen and (min-device-pixel-ratio: 2),
            only screen and (min-resolution: 192dpi),
            only screen and (min-resolution: 2dppx) {
            background-image: image-url('emoji@2x.png');
            background-size: #{SPRITESHEET_WIDTH}px #{SPRITESHEET_HEIGHT}px;
          }
          /* stylelint-enable media-feature-name-no-vendor-prefix */
        }
        CSS
      end
    end
    puts 'Done!'

    puts "\n"

    puts "Preparing sprites for HiDPI size: #{RETINA}px..."

    # Now do it again but for Retina
    Dir.mktmpdir do |tmpdir|
      # Copy the TanukiEmoji assets to the temporary folder for resizing
      FileUtils.cp_r(File.join(emoji_dir, '.'), tmpdir)

      Dir.chdir(tmpdir) do
        Dir["**/*.png"].each do |png|
          tmp_image_path = File.join(tmpdir, png)
          resize!(tmp_image_path, RETINA)
          print '.'
        end
      end
      puts ' Done!'

      puts "\n"

      print 'Compiling HiDPI sprites...'

      # Combine the resized assets into a packed sprite and re-generate the SCSS
      SpriteFactory.run!(tmpdir, {
        output_image: "app/assets/images/emoji@2x.png",
        style: false,
        nocomments: true,
        pngcrush: true,
        layout: :packed
      })
    end

    puts ' Done!'
  end

  def check_requirements!
    unless defined?(Magick)
      puts <<~MSG
      This task is disabled by default and should only be run when the TanukiEmoji
      gem is updated with new Emojis.

      To enable this task, *temporarily* add the following lines to Gemfile and
      re-bundle:

      gem 'rmagick', '~> 6.0'

      It depends on ImageMagick 6, which can be installed via HomeBrew with:

      brew unlink imagemagick
      brew install imagemagick@6 && brew link imagemagick@6 --force
      MSG

      exit 1
    end

    return if Dir.exist? Gitlab::Emoji.emoji_public_absolute_path

    puts <<~MSG
    You first need to import the assets for Emoji version: #{Gitlab::Emoji::EMOJI_VERSION}

    Run the following task:

    rake tanuki_emoji:import
    MSG

    exit 1
  end

  def resize!(image_path, size)
    # Resize the image in-place, save it, and free the object
    image = MiniMagick::Image.open(image_path)
    image.quality(100)
    image.resize("#{size}x#{size}")
    image.write(image_path)
  end
end
