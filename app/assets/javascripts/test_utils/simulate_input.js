function triggerEvents(input) {
  input.dispatchEvent(new Event('keydown'));
  input.dispatchEvent(new Event('keypress'));
  input.dispatchEvent(new Event('input'));
  input.dispatchEvent(new Event('keyup'));
}

export default function simulateInput(target, text) {
  const input = document.querySelector(target);
  if (!input || !input.matches('textarea, input')) {
    return false;
  }

  if (text.length > 0) {
    Array.prototype.forEach.call(text, (char) => {
      input.value += char;
      triggerEvents(input);
    });
  } else {
    triggerEvents(input);
  }
  return true;
}
