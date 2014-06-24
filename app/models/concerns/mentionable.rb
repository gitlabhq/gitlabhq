# == Mentionable concern
#
# Contains functionality related to objects that can mention Users, Issues, MergeRequests, or Commits by
# GFM references.
#
# Used by Issue, Note, MergeRequest, and Commit.
#
module Mentionable
  extend ActiveSupport::Concern

  module ClassMethods
    # Indicate which attributes of the Mentionable to search for GFM references.
    def attr_mentionable *attrs
      mentionable_attrs.concat(attrs.map(&:to_s))
    end

    # Accessor for attributes marked mentionable.
    def mentionable_attrs
      @mentionable_attrs ||= []
    end
  end

  # Generate a GFM back-reference that will construct a link back to this Mentionable when rendered. Must
  # be overridden if this model object can be referenced directly by GFM notation.
  def gfm_reference
    raise NotImplementedError.new("#{self.class} does not implement #gfm_reference")
  end

  # Construct a String that contains possible GFM references.
  def mentionable_text
    self.class.mentionable_attrs.map { |attr| send(attr) || '' }.join
  end

  # The GFM reference to this Mentionable, which shouldn't be included in its #references.
  def local_reference
    self
  end

  # Determine whether or not a cross-reference Note has already been created between this Mentionable and
  # the specified target.
  def has_mentioned? target
    Note.cross_reference_exists?(target, local_reference)
  end

  def mentioned_users
    users = []
    return users if mentionable_text.blank?
    has_project = self.respond_to? :project
    matches = mentionable_text.scan(/@[a-zA-Z][a-zA-Z0-9_\-\.]*/)
    matches.each do |match|
      identifier = match.delete "@"
      if identifier == "all"
        users += project.team.members.flatten
      else
        if has_project
          id = project.team.members.find_by(username: identifier).try(:id)
        else
          id = User.find_by(username: identifier).try(:id)
        end
        users << User.find(id) unless id.blank?
      end
    end
    users.uniq
  end

  # Extract GFM references to other Mentionables from this Mentionable. Always excludes its #local_reference.
  def references p = project, text = mentionable_text
    return [] if text.blank?
    ext = Gitlab::ReferenceExtractor.new
    ext.analyze(text)
    (ext.issues_for(p) + ext.merge_requests_for(p) + ext.commits_for(p)).uniq - [local_reference]
  end

  # Create a cross-reference Note for each GFM reference to another Mentionable found in +mentionable_text+.
  def create_cross_references! p = project, a = author, without = []
    refs = references(p) - without
    refs.each do |ref|
      Note.create_cross_reference_note(ref, local_reference, a, p)
    end
  end

  # If the mentionable_text field is about to change, locate any *added* references and create cross references for
  # them. Invoke from an observer's #before_save implementation.
  def notice_added_references p = project, a = author
    ch = changed_attributes
    original, mentionable_changed = "", false
    self.class.mentionable_attrs.each do |attr|
      if ch[attr]
        original << ch[attr]
        mentionable_changed = true
      end
    end

    # Only proceed if the saved changes actually include a chance to an attr_mentionable field.
    return unless mentionable_changed

    preexisting = references(p, original)
    create_cross_references!(p, a, preexisting)
  end

end
