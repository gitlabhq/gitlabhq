module Emoji
  path  = "#{Rails.root}/vendor/assets/images/emoji"
  NAMES = Dir["#{path}/*.png"].sort.map {|f| File.basename(f, '.png')}
end
