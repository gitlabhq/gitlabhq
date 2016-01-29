class RemoveDotAtomPathEndingOfProjects < ActiveRecord::Migration

  class ProjectPath
    def initilize(old_path)
      @old_path = old_path
    end

    def clean_path
      @_clean_path ||= PathCleaner.clean(@old_path)
    end
  end

  module PathCleaner
    def initialize(path)
      @path = path
    end

    def self.clean(*args)
      new(*args).clean
    end

    def clean
      path = cleaned_path
      count = 0
      while path_exists?(path)
        path = "#{cleaned_path}#{count}"
        count += 1
      end
      path
    end

    def cleaned_path
      @_cleaned_path ||= path.gsub(/\.atom\z/, '-atom')
    end

    def path_exists?(path)
      Project.find_by_path(path)
    end
  end

  def up
    projects_with_dot_atom.each do |project|
      remove_dot(project)
    end
  end

  private

  def remove_dot(project)
    #TODO
  end


end
