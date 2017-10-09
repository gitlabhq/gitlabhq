export const viewTypes = {
  TWO_UP: 'TWO_UP',
  SWIPE: 'SWIPE',
  ONION_SKIN: 'ONION_SKIN',
};

export function isValidViewType(validate) {
  return !!Object.getOwnPropertyNames(viewTypes).find(viewType => viewType === validate);
}
