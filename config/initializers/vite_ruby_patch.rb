# frozen_string_literal: true

# TODO: remove this module as soon as https://github.com/ElMassimo/vite_ruby/pull/556 lands
module ManifestPatch
  def resolve_references(manifest)
    asset_entries = {}
    manifest.each_value do |entry|
      file = entry["file"] = prefix_vite_asset(entry["file"])
      %w[css assets].each do |key|
        entry[key] = entry[key].map { |path| prefix_vite_asset(path) } if entry[key]
      end
      entry["imports"]&.map! { |name| manifest.fetch(name) }
      entry_name = entry["name"]
      if entry_name && entry["isEntry"]
        asset_entries["#{entry_name}.js"] = entry
        asset_entries[entry_name] = entry
        asset_entries[File.join(config.entrypoints_dir, "#{entry_name}.js")] = entry
        asset_entries[File.join(config.entrypoints_dir, entry_name)] = entry
      end
      # handle scss/css entrypoints
      entry["names"]&.each do |name|
        asset_entries[name] = {
          "isEntry" => true,
          "file" => file
        }
        asset_entries[File.join(config.entrypoints_dir, name)] = {
          "isEntry" => true,
          "file" => file
        }
      end
    end
    manifest.merge!(asset_entries)
  end
end

module ViteRubyPatch
  def manifest
    @manifest ||= ViteRuby::Manifest.new(self).tap do |m|
      m.extend(ManifestPatch)
    end
  end
end

Rails.application.config.after_initialize do
  ViteRuby.instance.extend(ViteRubyPatch)
end
