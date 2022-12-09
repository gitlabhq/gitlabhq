import csrf from '~/lib/utils/csrf';

export const createAndSubmitForm = ({ url, data }) => {
  const form = document.createElement('form');

  form.action = url;
  // For now we only support 'post'.
  // `form.method` doesn't support other methods so we would need to
  // use a hidden `_method` input, which is out of scope for now.
  form.method = 'post';
  form.style.display = 'none';

  Object.entries(data)
    .concat([['authenticity_token', csrf.token]])
    .forEach(([key, value]) => {
      const input = document.createElement('input');
      input.type = 'hidden';
      input.name = key;
      input.value = value;

      form.appendChild(input);
    });

  document.body.appendChild(form);
  form.submit();
};
