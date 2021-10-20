export function pickDirection({ line, code } = {}) {
  const { left, right } = line;
  let direction = left || right;

  if (right?.line_code === code) {
    direction = right;
  }

  return direction;
}
