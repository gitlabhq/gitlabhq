class PluginsSystem
  attr_accessor :plugins, :files

  def initialize
    @files = Dir.glob(Rails.root.join('plugins', '*_plugin.rb'))
  end

  def valid_plugins
    files.map do |file|
      file_name = File.basename(file, '.rb')

      # Just give sample data to method and expect it to not crash.
      begin
        klass = Object.const_get(file_name.classify)
        klass.new.execute(Gitlab::DataBuilder::Push::SAMPLE_DATA)
      rescue => e
        Rails.logger.warn("GitLab -> Plugins -> #{file_name} raised an exception during boot check. #{e}")
        next
      else
        Rails.logger.info "GitLab -> Plugins -> #{file_name} passed boot check"
        klass
      end
    end
  end
end

# Load external plugins from /plugins directory
# and set into PLUGINS variable
PLUGINS = PluginsSystem.new.valid_plugins
