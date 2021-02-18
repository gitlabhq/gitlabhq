export const generateUserPaths = (paths, id) => {
  return Object.fromEntries(
    Object.entries(paths).map(([action, genericPath]) => {
      return [action, genericPath.replace('id', id)];
    }),
  );
};
