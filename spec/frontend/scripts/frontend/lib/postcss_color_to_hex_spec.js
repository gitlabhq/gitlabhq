import postcss from 'postcss';
import { postCssColorToHex } from '../../../../../scripts/frontend/lib/postcss_color_to_hex';

describe('postcssColorToHex', () => {
  function convert(css) {
    return postcss(postCssColorToHex()).process(css).toString();
  }

  it('converts non-transparent colors to hex', () => {
    expect(
      convert(`.foo {
  --example: #fff;
  color: rgba(255,0,0);
  color: rgba(0 255 0);
  color: #abcdef;
  color: white;
  color: hsl(90, 100%, 100%);
}`),
    ).toBe(`.foo {
  --example: #ffffff;
  color: #ff0000;
  color: #00ff00;
  color: #abcdef;
  color: #ffffff;
  color: #ffffff;
}`);
  });

  it('returns `transparent` for alpha = 0', () => {
    expect(
      convert(`.foo {
  color: transparent;
  color: rgba(0,0,0,0);
}`),
    ).toBe(`.foo {
  color: transparent;
  color: transparent;
}`);
  });

  it('converts colors with alpha to rgba', () => {
    expect(
      convert(`.foo {
  --example: #fff7;
  color: rgba(255,0,0,0.05);
  color: #abcdef7f;
  color: hsl(90 100% 100% / 60%);
}`),
    ).toBe(`.foo {
  --example: rgba(255,255,255,.47);
  color: rgba(255,0,0,.05);
  color: rgba(171,205,239,.5);
  color: rgba(255,255,255,.6);
}`);
  });

  it('ignores non-color values', () => {
    const input = `.foo {
  --example: 1rem;
  margin: 5px;
  padding: 5%;
  z-index: clamp(1,2,3);
}`;

    expect(convert(input)).toBe(input);
  });
});
