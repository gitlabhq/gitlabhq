export default function stubChildren(Component) {
  return Object.fromEntries(Object.keys(Component.components).map((c) => [c, true]));
}
