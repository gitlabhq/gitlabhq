((global) => {
  const TOKEN_KEYS = ['author', 'assignee', 'milestone', 'label', 'weight'];

  class Tokenizer {
    static checkTokens(event) {
      const value = event.target.value;

      const split = value.toLowerCase().split(' ');
      const text = split.length === 1 ? split[0] : split[split.length - 1];
      const hasColon = text[text.length - 1] === ':';
      const token = text.slice(0, -1);

      if (hasColon && TOKEN_KEYS.indexOf(token) != -1) {
        // One for the colon and one for the space before it
        const textWithoutToken = value.substring(0, value.length - token.length - 2)
        gl.Tokenizer.addTextToken(textWithoutToken, event.target);

        const tokenKey = token.charAt(0).toUpperCase() + token.slice(1);
        gl.Tokenizer.addToken(tokenKey, event.target);

        event.target.value = '';
        event.target.placeholder = '';

        if (token === 'author') {

          let ul = event.target.nextElementSibling;
          ul.setAttribute('data-dynamic', true);

          ul.innerHTML = `<li>
            <img src="{{avatar_url}}" class="avatar" width="30">
            <strong class="dropdown-menu-user-full-name"> {{name}} </strong>
            <span class="dropdown-menu-user-username"> @{{username}} </span>
          </li>`;
          droplab.addData('filterDropdownInput', '/autocomplete/users.json?search=&per_page=20&active=true&project_id=2&group_id=&skip_ldap=&current_user=true&push_code_to_protected_branches=&author_id=&skip_users=');
        }

        // event.target.nextElementSibling.innerHTML += `<li><span>test</span></li>`;
        droplab.addHook(event.target);
      }
    }

    static addTextToken(text, inputNode) {
      const listItem = inputNode.parentNode;
      const fragmentList = listItem.parentNode;

      let fragmentToken = document.createElement('li');
      fragmentToken.innerHTML = `<span>${text}</span>`

      fragmentList.insertBefore(fragmentToken, listItem);

      // TODO: AddEventListener for Click => converts span into input
      // Note: What if each text token remained as an input?
    }

    static addToken(key, inputNode) {
      const listItem = inputNode.parentNode;
      const fragmentList = listItem.parentNode;

      let fragmentToken = document.createElement('li');
      fragmentToken.classList.add('fragment-token');
      fragmentToken.innerHTML = `<span class="fragment-key">${key}</span>`

      fragmentList.insertBefore(fragmentToken, listItem);

      // TODO: AddEventListener for Click => darken and move cursor
      // TODO: AddEventListener for DoubleClick Editing Mode
      // TODO: Add `x` for deleting entire token
    }

    static deleteToken(inputNode) {
      const listItem = inputNode.parentNode;
      const fragmentList = listItem.parentNode;
      const fragments = fragmentList.childNodes.length;

      if (fragments === 1) {
        // Only input fragment found in fragmentList
        return;
      }

      fragmentList.removeChild(listItem.previousSibling);
    }
  }

  global.Tokenizer = Tokenizer;
})(window.gl || (window.gl = {}));
