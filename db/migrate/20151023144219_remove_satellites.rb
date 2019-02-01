require 'fileutils'

class RemoveSatellites < ActiveRecord::Migration[4.2]
  def up
    satellites = Gitlab.config['satellites']
    return if satellites.nil?

    satellites_path = satellites['path']
    return if satellites_path.nil?

    FileUtils.rm_rf(satellites_path)
  end

  def down
    # Do nothing
  end
end
