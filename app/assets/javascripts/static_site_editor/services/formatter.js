const removeOrphanedBrTags = source => {
  /* Until the underlying Squire editor of Toast UI Editor resolves duplicate `<br>` tags, this
    `replace` solution will clear out orphaned `<br>` tags that it generates. Additionally,
    it cleans up orphaned `<br>` tags in the source markdown document that should be new lines.
    https://gitlab.com/gitlab-org/gitlab/-/issues/227602#note_380765330
  */
  return source.replace(/\n^<br>$/gm, '');
};

const format = source => {
  return removeOrphanedBrTags(source);
};

export default format;
