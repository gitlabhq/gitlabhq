let realLocation;

export function mockLocation(href) {
  realLocation = global.location;
  delete global.location;
  global.location = { href };
}

export function restoreLocation() {
  global.location = realLocation;
}
