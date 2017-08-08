module Gitlab
  module Git
    module Local
      module Repository
        def local_languages(ref)
          ref ||= rugged.head.target_id
          languages = Linguist::Repository.new(rugged, ref).languages
          total = languages.map(&:last).sum
  
          languages = languages.map do |language|
            name, share = language
            color = Linguist::Language[name].color || "##{Digest::SHA256.hexdigest(name)[0...6]}"
            {
              value: (share.to_f * 100 / total).round(2),
              label: name,
              color: color,
              highlight: color
            }
          end
  
          languages.sort do |x, y|
            y[:value] <=> x[:value]
          end
        end
      end
    end
  end
end
