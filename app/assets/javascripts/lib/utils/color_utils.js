/*
  Generates a color based on a HSV to RGB conversion.
  This takes a hue, saturation and value/brightness values
  ranging from 0 to 1, keep in mind hue values come from 0 to 360
  so you need to convert it prior passing it.
  Resulting in an array where:
  [0]: Red
  [1]: Green
  [2]: Blue
  these values can range from 0 to 255
*/

export function hsvToRgb(hue, sat, val) {
  const hi = parseInt(hue * 6, 10);
  const f = (hue * 6) - hi;
  if (sat === 0 || sat === undefined) {
    return [parseInt(val * 256, 10), parseInt(val * 256, 10), parseInt(val * 256, 10)];
  }
  const p = val * (1 - sat);
  const q = val * (1 - (f * sat));
  const t = val * (1 - ((1 - f) * sat));
  let r = 0; // Red, green and blue outputs
  let g = 0;
  let b = 0;
  switch (hi) {
    case 0:
      r = val;
      g = t;
      b = p;
      break;
    case 1:
      r = q;
      g = val;
      b = p;
      break;
    case 2:
      r = p;
      g = val;
      b = t;
      break;
    case 3:
      r = p;
      g = q;
      b = val;
      break;
    case 4:
      r = t;
      g = p;
      b = val;
      break;
    case 5:
      r = val;
      g = p;
      b = q;
      break;
    default:
      r = val;
      g = p;
      b = q;
      break;
  }
  return [parseInt(r * 256, 10), parseInt(g * 256, 10), parseInt(b * 256, 10)];
}

export function degreesToRadians(degrees) {
  if (typeof degrees !== 'number') {
    return 0;
  }
  const deg = parseInt(degrees, 10);
  return (deg * Math.PI) / 180;
}

/*
  Generates a color based on a RGB to HSV conversion.
  This takes an array with [Red, Green, Blue] where each values ranges from 0 to 255
  and returns an array where
  [0]: Hue
  [1]: Saturation
  [2]: Value/Brightness
  these values range from 0 to 1
*/
export function rgbToHsv(color) {
  const r = color[0];
  const g = color[1];
  const b = color[2];
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let hue;
  let sat;
  const val = max / 255;
  let delta;
  // Get Hue
  if (max === min) {
    hue = 0;
  } else if (max === r && g >= b) {
    delta = (g - b) / (max - min);
    hue = (60 * delta) + 0;
  } else if (max === r && g < b) {
    delta = (g - b) / (max - min);
    hue = (60 * delta) + 360;
  } else if (max === g) {
    delta = (b - r) / (max - min);
    hue = (60 * delta) + 120;
  } else if (max === b) {
    delta = (r - g) / (max - min);
    hue = (60 * delta) + 240;
  }
  hue = hue /= 360;
  // Get Saturation
  if (max === 0) {
    sat = 0;
  } else {
    sat = 1 - (min / max);
  }
  return [hue, sat, val];
}
