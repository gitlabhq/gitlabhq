# frozen_string_literal: true

module BlobViewer
  class CargoToml < DependencyManager
    include Static

    self.file_types = %i(cargo_toml)

    def manager_name
      'Cargo'
    end

    def manager_url
      'https://crates.io/'
    end
  end
end
