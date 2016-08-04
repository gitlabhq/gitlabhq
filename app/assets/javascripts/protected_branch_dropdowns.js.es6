class ProtectedBranchDropdowns {
  constructor(options) {
    const { $dropdowns, onSelect } = options;

    $dropdowns.each((i, el) => {
      new ProtectedBranchDropdown({
        $dropdown: $(el),
        onSelect: onSelect
      });
    });
  }
 }
