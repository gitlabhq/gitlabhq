import { colorFromDefaultPalette } from '@gitlab/ui/src/utils/charts/theme';

export function assignUserColor(userId) {
  return colorFromDefaultPalette(Math.abs(userId ?? 0));
}
