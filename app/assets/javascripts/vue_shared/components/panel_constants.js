// Default panel min width: 25rem at 16px base
// 25rem at 16px base. Mirrors the floor of `clamp(25rem, 20vw, 35rem)` in
// `--ai-panel-width`; keep in sync with that declaration if either changes.
export const MIN_PANEL_PX = 400;

// 60rem at 16px base. Upper bound for drag-resize; pure JS-side cap.
export const MAX_AI_PANEL_PX = 960;
