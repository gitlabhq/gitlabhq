class ProtectedBranch < ActiveRecord::Base
  include Gitlab::ShellAdapter

  belongs_to :project
  validates :name, presence: true
  validates :project, presence: true

  has_many :merge_access_levels, dependent: :destroy
  has_many :push_access_levels, dependent: :destroy

  validates_length_of :merge_access_levels, is: 1, message: "are restricted to a single instance per protected branch."
  validates_length_of :push_access_levels, is: 1, message: "are restricted to a single instance per protected branch."

  accepts_nested_attributes_for :push_access_levels
  accepts_nested_attributes_for :merge_access_levels

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

  # Returns all branches (among the given list of branches [`Gitlab::Git::Branch`])
  # that match the current protected branch.
  def matching(branches)
    branches.select { |branch| self.matches?(branch.name) }
  end

  # Checks if the protected branch matches the given branch name.
  def matches?(branch_name)
    return false if self.name.blank?

    exact_match?(branch_name) || wildcard_match?(branch_name)
  end

  # Checks if this protected branch contains a wildcard
  def wildcard?
    self.name && self.name.include?('*')
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
