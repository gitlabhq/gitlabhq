class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter

  belongs_to :project
  validates :name, presence: true
  validates :project, presence: true

  def commit
    project.commit(self.name)
  end

  # Returns all protected branches that match the given branch name.
  # This realizes all records from the scope built up so far, and does
  # _not_ return a relation.
  #
  # This method optionally takes in a list of `protected_branches` to search
  # through, to avoid calling out to the database.
  def self.matching(branch_name, protected_branches: nil)
    (protected_branches || all).select { |protected_branch| protected_branch.matches?(branch_name) }
  end

  # Checks if the protected branch matches the given branch name.
  def matches?(branch_name)
    return false if self.name.blank?

    exact_match?(branch_name) || wildcard_match?(branch_name)
  end

  protected

  def exact_match?(branch_name)
    self.name == branch_name
  end

  def wildcard_match?(branch_name)
    wildcard_regex === branch_name
  end

  def wildcard_regex
    @wildcard_regex ||= begin
      name = self.name.gsub('*', 'STAR_DONT_ESCAPE')
      quoted_name = Regexp.quote(name)
      regex_string = quoted_name.gsub('STAR_DONT_ESCAPE', '.*?')
      /\A#{regex_string}\z/
    end
  end
end
