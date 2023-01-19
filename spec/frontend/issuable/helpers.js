export function getSaveableFormChildren(form, exclude = ['input.js-toggle-draft']) {
  const children = Array.from(form.children);
  const saveable = children.filter((e) => {
    const isFiltered = exclude.reduce(
      ({ isFiltered: filtered, element }, selector) => {
        return {
          isFiltered: filtered || element.matches(selector),
          element,
        };
      },
      { isFiltered: false, element: e },
    );

    return !isFiltered.isFiltered;
  });

  return saveable;
}
