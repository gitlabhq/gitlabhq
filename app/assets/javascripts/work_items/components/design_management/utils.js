export const findVersionId = (id) => (id.match('::Version/(.+$)') || [])[1];
