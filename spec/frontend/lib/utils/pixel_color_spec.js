import { averageColorFromPixels } from '~/lib/utils/pixel_color';

describe('lib/utils/pixel_color averageColorFromPixels', () => {
  it('returns fallback when no pixels qualify (all alpha below threshold)', () => {
    const data = new Uint8ClampedArray([
      0,
      255,
      0,
      10, // near-transparent green
      255,
      0,
      0,
      0, // transparent red
    ]);
    expect(averageColorFromPixels(data, 16, 'gray')).toBe('gray');
  });

  it('averages opaque pixels correctly', () => {
    const data = new Uint8ClampedArray([
      100,
      0,
      0,
      255, // red 100
      200,
      0,
      0,
      255, // red 200
    ]);
    expect(averageColorFromPixels(data, 16, 'gray')).toBe('rgb(150, 0, 0)');
  });

  it('applies alpha-weighting', () => {
    const half = 128; // ≈0.5
    const data = new Uint8ClampedArray([
      255,
      0,
      0,
      255, // opaque red
      0,
      0,
      255,
      half, // half-blue
    ]);
    // r = 255*1 + 0*0.5 = 255; b = 255*0.5 = 127.5; w = 1.5 → avg ≈ (170, 0, 85)
    expect(averageColorFromPixels(data, 16, 'gray')).toBe('rgb(170, 0, 85)');
  });

  it('respects the alpha threshold boundary (includes a=16, excludes a=15)', () => {
    const data = new Uint8ClampedArray([
      10,
      10,
      10,
      15, // ignored
      100,
      50,
      25,
      16, // included
    ]);
    expect(averageColorFromPixels(data, 16, 'gray')).toBe('rgb(100, 50, 25)');
  });

  it('handles empty data', () => {
    expect(averageColorFromPixels(new Uint8ClampedArray(), 16, 'gray')).toBe('gray');
  });
});
