// 'template-selected' -> 'onTemplateSelected'. Mirrors Vue 3's toHandlerKey
// plus the camelization @vue/compat applies when converting legacy `on:`
// vnode data; Vue 3's emit tries both the verbatim and the camelized handler
// key, so camelized keys match events emitted under either spelling.
export const toHandlerKey = (event) =>
  `on${event.replace(/-(\w)/g, (_, c) => c.toUpperCase()).replace(/^./, (c) => c.toUpperCase())}`;
