namespace :gemojione do
  desc 'Generates Emoji SHA256 digests'

  task aliases: ['yarn:check', 'environment'] do
    require 'json'

    aliases = {}

    index_file = File.join(Rails.root, 'fixtures', 'emojis', 'index.json')
    index = JSON.parse(File.read(index_file))

    index.each_pair do |key, data|
      data['aliases'].each do |a|
        a.tr!(':', '')

        aliases[a] = key
      end
    end

    out = File.join(Rails.root, 'fixtures', 'emojis', 'aliases.json')
    File.open(out, 'w') do |handle|
      handle.write(JSON.pretty_generate(aliases, indent: '   ', space: '', space_before: ''))
    end
  end

  task digests: ['yarn:check', 'environment'] do
    require 'digest/sha2'
    require 'json'

    # We don't have `node_modules` available in built versions of GitLab
    FileUtils.cp_r(Rails.root.join('node_modules', 'emoji-unicode-version', 'emoji-unicode-version-map.json'), File.join(Rails.root, 'fixtures', 'emojis'))

    dir = Gemojione.images_path
    resultant_emoji_map = {}

    Gitlab::Emoji.emojis.each do |name, emoji_hash|
      # Ignore aliases
      unless Gitlab::Emoji.emojis_aliases.key?(name)
        fpath = File.join(dir, "#{emoji_hash['unicode']}.png")
        hash_digest = Digest::SHA256.file(fpath).hexdigest

        category = emoji_hash['category']
        if name == 'gay_pride_flag'
          category = 'flags'
        end

        entry = {
          category: category,
          moji: emoji_hash['moji'],
          description: emoji_hash['description'],
          unicodeVersion: Gitlab::Emoji.emoji_unicode_version(name),
          digest: hash_digest
        }

        resultant_emoji_map[name] = entry
      end
    end

    out = File.join(Rails.root, 'fixtures', 'emojis', 'digests.json')
    File.open(out, 'w') do |handle|
      handle.write(JSON.pretty_generate(resultant_emoji_map))
    end
  end

  # This task will generate a standard and Retina sprite of all of the current
  # Gemojione Emojis, with the accompanying SCSS map.
  #
  # It will not appear in `rake -T` output, and the dependent gems are not
  # included in the Gemfile by default, because this task will only be needed
  # occasionally, such as when new Emojis are added to Gemojione.
  task sprite: :environment do
    begin
      require 'sprite_factory'
      require 'rmagick'
    rescue LoadError
      # noop
    end

    check_requirements!

    SIZE   = 20
    RETINA = SIZE * 2

    # Update these values to the width and height of the spritesheet when
    # new emoji are added.
    SPRITESHEET_WIDTH = 860
    SPRITESHEET_HEIGHT = 840

    # Setup a map to rename image files
    emoji_unicode_string_to_name_map = {}
    Gitlab::Emoji.emojis.each do |name, emoji_hash|
      # Ignore aliases
      unless Gitlab::Emoji.emojis_aliases.key?(name)
        emoji_unicode_string_to_name_map[emoji_hash['unicode']] = name
      end
    end

    # Copy the Gemojione assets to the temporary folder for renaming
    emoji_dir = "app/assets/images/emoji"
    FileUtils.rm_rf(emoji_dir)
    FileUtils.mkdir_p(emoji_dir, mode: 0700)
    FileUtils.cp_r(File.join(Gemojione.images_path, '.'), emoji_dir)
    Dir[File.join(emoji_dir, "**/*.png")].each do |png|
      image_path = png
      rename_to_named_emoji_image!(emoji_unicode_string_to_name_map, image_path)
    end

    Dir.mktmpdir do |tmpdir|
      FileUtils.cp_r(File.join(emoji_dir, '.'), tmpdir)

      Dir.chdir(tmpdir) do
        Dir["**/*.png"].each do |png|
          tmp_image_path = File.join(tmpdir, png)
          resize!(tmp_image_path, SIZE)
        end
      end

      style_path = Rails.root.join(*%w(app assets stylesheets framework emoji_sprites.scss))

      # Combine the resized assets into a packed sprite and re-generate the SCSS
      SpriteFactory.cssurl = "image-url('$IMAGE')"
      SpriteFactory.run!(tmpdir, {
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
      system(%Q(sed -i '' "s/ 0px/ 0/g" #{style_path}))

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

          @media only screen and (-webkit-min-device-pixel-ratio: 2),
                 only screen and (min--moz-device-pixel-ratio: 2),
                 only screen and (-o-min-device-pixel-ratio: 2/1),
                 only screen and (min-device-pixel-ratio: 2),
                 only screen and (min-resolution: 192dpi),
                 only screen and (min-resolution: 2dppx) {
            background-image: image-url('emoji@2x.png');
            background-size: #{SPRITESHEET_WIDTH}px #{SPRITESHEET_HEIGHT}px;
          }
        }
        CSS
      end
    end

    # Now do it again but for Retina
    Dir.mktmpdir do |tmpdir|
      # Copy the Gemojione assets to the temporary folder for resizing
      FileUtils.cp_r(File.join(emoji_dir, '.'), tmpdir)

      Dir.chdir(tmpdir) do
        Dir["**/*.png"].each do |png|
          tmp_image_path = File.join(tmpdir, png)
          resize!(tmp_image_path, RETINA)
        end
      end

      # Combine the resized assets into a packed sprite and re-generate the SCSS
      SpriteFactory.run!(tmpdir, {
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

  EMOJI_IMAGE_PATH_RE = /(.*?)(([0-9a-f]-?)+)\.png$/i
  def rename_to_named_emoji_image!(emoji_unicode_string_to_name_map, image_path)
    # Rename file from unicode to emoji name
    matches = EMOJI_IMAGE_PATH_RE.match(image_path)
    preceding_path = matches[1]
    unicode_string = matches[2]
    name = emoji_unicode_string_to_name_map[unicode_string]
    if name
      new_png_path = File.join(preceding_path, "#{name}.png")
      FileUtils.mv(image_path, new_png_path)
      new_png_path
    else
      puts "Warning: emoji_unicode_string_to_name_map missing entry for #{unicode_string}. Full path: #{image_path}"
    end
  end
end
