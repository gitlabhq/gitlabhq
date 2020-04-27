function isCheckableType(type) {
  return /^(radio|checkbox)$/.test(type);
}

export function setInputValue(element, value) {
  const { type } = element;
  let eventType;

  if (isCheckableType(type)) {
    element.checked = !element.checked;
    eventType = 'change';
  } else {
    element.value = value;
    eventType = 'input';
  }

  element.dispatchEvent(
    new Event(eventType, {
      bubbles: true,
    }),
  );
}

export function getInputValue(input) {
  return isCheckableType(input.type) ? input.checked : input.value;
}

export function createForm(type = 'text') {
  const form = document.createElement('form');
  form.innerHTML = `
    <input type="${type}" name="${type}" class="js-input"/>
    <button type="submit" class="js-dirty-submit"></button>
  `;

  const input = form.querySelector('.js-input');
  const submit = form.querySelector('.js-dirty-submit');

  return {
    form,
    input,
    submit,
  };
}
