class AllowedToPushDropdowns {
  constructor (options) {
    const { $dropdowns, onSelect } = options;

    $dropdowns.each((i, el) => {
      new ProtectedBranchAccessDropdown({
        $dropdown: $(el),
        data: gon.push_access_levels,
        onSelect: onSelect
      });
    });
  }
}