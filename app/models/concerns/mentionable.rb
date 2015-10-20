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
    def attr_mentionable(*attrs)
      mentionable_attrs.concat(attrs.map(&:to_s))
    end

    # Accessor for attributes marked mentionable.
    def mentionable_attrs
      @mentionable_attrs ||= []
    end
  end

  included do
    if self < Participable
      participant ->(current_user) { mentioned_users(current_user, load_lazy_references: false) }
    end
  end

  # Returns the text used as the body of a Note when this object is referenced
  #
  # By default this will be the class name and the result of calling
  # `to_reference` on the object.
  def gfm_reference(from_project = nil)
    # "MergeRequest" > "merge_request" > "Merge request" > "merge request"
    friendly_name = self.class.to_s.underscore.humanize.downcase

    "#{friendly_name} #{to_reference(from_project)}"
  end

  # Construct a String that contains possible GFM references.
  def mentionable_text
    self.class.mentionable_attrs.map { |attr| send(attr) }.compact.join("\n\n")
  end

  # The GFM reference to this Mentionable, which shouldn't be included in its #references.
  def local_reference
    self
  end

  def all_references(current_user = self.author, text = self.mentionable_text, load_lazy_references: true)
    ext = Gitlab::ReferenceExtractor.new(self.project, current_user, load_lazy_references: load_lazy_references)
    ext.analyze(text)
    ext
  end

  def mentioned_users(current_user = nil, load_lazy_references: true)
    all_references(current_user, load_lazy_references: load_lazy_references).users
  end

  # Extract GFM references to other Mentionables from this Mentionable. Always excludes its #local_reference.
  def referenced_mentionables(current_user = self.author, text = self.mentionable_text, load_lazy_references: true)
    return [] if text.blank?

    refs = all_references(current_user, text, load_lazy_references: load_lazy_references)
    (refs.issues + refs.merge_requests + refs.commits) - [local_reference]
  end

  # Create a cross-reference Note for each GFM reference to another Mentionable found in +mentionable_text+.
  def create_cross_references!(author = self.author, without = [], text = self.mentionable_text)
    refs = referenced_mentionables(author, text)
    
    # We're using this method instead of Array diffing because that requires
    # both of the object's `hash` values to be the same, which may not be the
    # case for otherwise identical Commit objects.
    refs.reject! { |ref| without.include?(ref) || cross_reference_exists?(ref) }

    refs.each do |ref|
      SystemNoteService.cross_reference(ref, local_reference, author)
    end
  end

  # When a mentionable field is changed, creates cross-reference notes that
  # don't already exist
  def create_new_cross_references!(author = self.author)
    changes = detect_mentionable_changes

    return if changes.empty?

    original_text = changes.collect { |_, vals| vals.first }.join(' ')

    preexisting = referenced_mentionables(author, original_text)
    create_cross_references!(author, preexisting)
  end

  private

  # Returns a Hash of changed mentionable fields
  #
  # Preference is given to the `changes` Hash, but falls back to
  # `previous_changes` if it's empty (i.e., the changes have already been
  # persisted).
  #
  # See ActiveModel::Dirty.
  #
  # Returns a Hash.
  def detect_mentionable_changes
    source = (changes.present? ? changes : previous_changes).dup

    mentionable = self.class.mentionable_attrs

    # Only include changed fields that are mentionable
    source.select { |key, val| mentionable.include?(key) }
  end
  
  # Determine whether or not a cross-reference Note has already been created between this Mentionable and
  # the specified target.
  def cross_reference_exists?(target)
    SystemNoteService.cross_reference_exists?(target, local_reference)
  end
end
