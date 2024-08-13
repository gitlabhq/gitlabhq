const { colord, extend } = require('colord');
const namesPlugin = require('colord/plugins/names');
const minifyPlugin = require('colord/plugins/minify');

extend([namesPlugin, minifyPlugin]);

const hexify = (value) => {
  const newValue = colord(value);
  if (newValue.isValid()) {
    // value has an alpha: return as rgba
    if (newValue.alpha() < 1) {
      return newValue.minify({
        rgb: true,
        transparent: true,
        hsl: false,
        hex: false,
      });
    }
    // value has no alpha, return as hex
    return newValue.toHex();
  }
  // Not a valid color, just return the input.
  return value;
};

const postCssColorToHex = () => {
  return {
    postcssPlugin: 'postcss-color-to-hex',
    Declaration(decl) {
      // eslint-disable-next-line
      decl.value = hexify(decl.value);
    },
  };
};
postCssColorToHex.postcss = true;

module.exports = {
  postCssColorToHex,
};
