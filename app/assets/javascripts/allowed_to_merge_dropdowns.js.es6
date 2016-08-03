class AllowedToMergeDropdowns {
  constructor (options) {
    const { $dropdowns, onSelect } = options;

    $dropdowns.each((i, el) => {
      new ProtectedBranchAccessDropdown({
        $dropdown: $(el),
        data: gon.merge_access_levels,
        onSelect: onSelect
      });
    });
  }
}
