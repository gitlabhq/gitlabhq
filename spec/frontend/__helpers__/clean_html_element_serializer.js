// slot-scope attribute is a result of Vue.js 3 stubs being serialized in slot context, drop it
// modelModifiers are result of Vue.js 3 model modifiers handling and should not be in snapshot
const ATTRIBUTES_TO_REMOVE = ['slot-scope', 'modelmodifiers'];
// Taken from https://github.com/vuejs/vue/blob/72aed6a149b94b5b929fb47370a7a6d4cb7491c5/src/platforms/web/util/attrs.ts#L37-L44
const BOOLEAN_ATTRIBUTES = new Set(
  (
    'allowfullscreen,async,autofocus,autoplay,checked,compact,controls,declare,' +
    'default,defaultchecked,defaultmuted,defaultselected,defer,disabled,' +
    'enabled,formnovalidate,hidden,indeterminate,inert,ismap,itemscope,loop,multiple,' +
    'muted,nohref,noresize,noshade,novalidate,nowrap,open,pauseonexit,readonly,' +
    'required,reversed,scoped,seamless,selected,sortable,' +
    'truespeed,typemustmatch,visible'
  ).split(','),
);

function sortClassesAlphabetically(node) {
  // Make classes render in alphabetical order for both Vue2 and Vue3
  if (node.hasAttribute('class')) {
    const classes = node.getAttribute('class');
    if (classes === '') {
      node.removeAttribute('class');
    } else {
      node.setAttribute('class', Array.from(node.classList).sort().join(' '));
    }
  }
}

const TRANSITION_VALUES_TO_REMOVE = [
  { attributeName: 'css', defaultValue: 'true' },
  { attributeName: 'persisted', defaultValue: 'true' },
];
function removeInternalPropsLeakingToTransitionStub(node) {
  TRANSITION_VALUES_TO_REMOVE.forEach((hash) => {
    if (node.getAttribute(hash.attributeName) === hash.defaultValue) {
      node.removeAttribute(hash.attributeName);
    }
  });
}

function normalizeText(node) {
  const newText = node.textContent.trim();
  const textWithoutNewLines = newText.replace(/\n/g, '');
  const textWithoutDeepSpace = textWithoutNewLines.replace(/(?<=\S)\s+/g, ' ');
  // eslint-disable-next-line no-param-reassign
  node.textContent = textWithoutDeepSpace;
}

const visited = new WeakSet();

// Lovingly borrowed from https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model/Whitespace#whitespace_helper_functions
function isAllWhitespace(node) {
  return !/[^\t\n\r ]/.test(node.textContent);
}

function isIgnorable(node) {
  return (
    node.nodeType === Node.COMMENT_NODE || // A comment node
    (node.nodeType === Node.TEXT_NODE && isAllWhitespace(node))
  ); // a text node, all ws
}

const REFERENCE_ATTRIBUTES = ['aria-controls', 'aria-labelledby', 'for'];
function updateIdTags(root) {
  const elementsWithIds = [...(root.id ? [root] : []), ...root.querySelectorAll('[id]')];

  const referenceSelector = REFERENCE_ATTRIBUTES.map((attr) => `[${attr}]`).join(',');
  const elementsWithReference = [
    ...(root.matches(referenceSelector) ? [root] : []),
    ...root.querySelectorAll(REFERENCE_ATTRIBUTES.map((attr) => `[${attr}]`).join(',')),
  ];

  elementsWithReference.forEach((el) => {
    REFERENCE_ATTRIBUTES.filter((attr) => el.getAttribute(attr)).forEach((target) => {
      const index = elementsWithIds.findIndex((t) => t.id === el.getAttribute(target));
      if (index !== -1) {
        el.setAttribute(target, `reference-${index}`);
      }
    });
  });

  elementsWithIds.forEach((el, index) => {
    el.setAttribute('id', `reference-${index}`);
  });
}

export function test(received) {
  return received instanceof Element && !visited.has(received);
}

// eslint-disable-next-line max-params
export function serialize(received, config, indentation, depth, refs, printer) {
  // Explicitly set empty string values of img.src to `null` as Vue3 does
  // We need to do this before `clone`, otherwise src prop diff will be lost
  received.querySelectorAll('img').forEach((img) => img.setAttribute('src', img.src || null));

  const clone = received.cloneNode(true);

  updateIdTags(clone);
  visited.add(clone);

  const iterator = document.createNodeIterator(
    clone,
    // eslint-disable-next-line no-bitwise
    NodeFilter.SHOW_COMMENT | NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT,
  );
  const ignorableNodes = [];

  for (let currentNode = iterator.nextNode(); currentNode; currentNode = iterator.nextNode()) {
    if (isIgnorable(currentNode)) {
      ignorableNodes.push(currentNode);
    } else {
      if (currentNode instanceof Element) {
        ATTRIBUTES_TO_REMOVE.forEach((attr) => currentNode.removeAttribute(attr));

        if (!currentNode.tagName.includes('-')) {
          // We want to normalize boolean attributes rendering only on native tags
          BOOLEAN_ATTRIBUTES.forEach((attr) => {
            if (currentNode.hasAttribute(attr) && currentNode.getAttribute(attr) === attr) {
              currentNode.setAttribute(attr, '');
            }
          });
        }

        sortClassesAlphabetically(currentNode);

        if (currentNode.tagName === 'TRANSITION-STUB') {
          removeInternalPropsLeakingToTransitionStub(currentNode);
        }
      }

      if (currentNode.nodeType === Node.TEXT_NODE) {
        normalizeText(currentNode);
      }

      currentNode.normalize();
      visited.add(currentNode);
    }
  }

  ignorableNodes.forEach((x) => x.remove());

  return printer(clone, config, indentation, depth, refs);
}
