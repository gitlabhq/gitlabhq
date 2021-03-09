# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
#
# Disables `GC.compact` method via monkey-patching.
# This is temporary measure to deal with reguarly appearing compacting issues (resulting in segfaults) in external gems.
# Having this patch allow using `nakayoshi_fork` in `config/puma.rb`,
# only without `GC.compact` (still invoking 4 GC cycles).
# Refer to for details: https://github.com/puma/puma/blob/80274413b04fae77cac7a7fecab7d6e89204343b/lib/puma/util.rb#L27

# rubocop:disable Rails/Output
module NakayoshiForkCompacting
  module MonkeyPatch
    def compact
      puts 'Note: GC compacting is currently disabled.'\
        ' Refer to `config/initializers_before_autoloader/003_gc_compact.rb` for details.'
    end
  end
end

GC.singleton_class.prepend NakayoshiForkCompacting::MonkeyPatch
