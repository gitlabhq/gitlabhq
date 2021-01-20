export default {
  test(value) {
    return value instanceof HTMLElement && !value.$_hit;
  },
  print(element, serialize) {
    element.$_hit = true;
    element.querySelectorAll('[style]').forEach((el) => {
      el.$_hit = true;
      if (el.style.display === 'none') {
        el.textContent = '(jest: contents hidden)';
      }
    });

    return serialize(element)
      .replace(/^\s*<!---->$/gm, '')
      .replace(/\n\s*\n/gm, '\n');
  },
};
