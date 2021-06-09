const resetActiveInArray = (arr) => arr?.map((menuItem) => ({ ...menuItem, active: false }));

/**
 * This method sets `active: false` for the menu items within the given nav data.
 *
 * @returns navData with the menu items updated with `active: false`
 */
export const resetMenuItemsActive = ({ primary, secondary, ...navData }) => {
  return {
    ...navData,
    primary: resetActiveInArray(primary),
    secondary: resetActiveInArray(secondary),
  };
};
