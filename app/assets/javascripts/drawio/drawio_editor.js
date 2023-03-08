import _ from 'lodash';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { darkModeEnabled } from '~/lib/utils/color_utils';
import { __ } from '~/locale';
import { setAttributes } from '~/lib/utils/dom_utils';
import {
  DARK_BACKGROUND_COLOR,
  DRAWIO_EDITOR_URL,
  DRAWIO_FRAME_ID,
  DIAGRAM_BACKGROUND_COLOR,
  DRAWIO_IFRAME_TIMEOUT,
  DIAGRAM_MAX_SIZE,
} from './constants';

function updateDrawioEditorState(drawIOEditorState, data) {
  Object.assign(drawIOEditorState, data);
}

function postMessageToDrawioEditor(drawIOEditorState, message) {
  const { origin } = new URL(DRAWIO_EDITOR_URL);

  drawIOEditorState.iframe.contentWindow.postMessage(JSON.stringify(message), origin);
}

function disposeDrawioEditor(drawIOEditorState) {
  drawIOEditorState.disposeEventListener();
  drawIOEditorState.iframe.remove();
}

function getSvg(data) {
  const svgPath = atob(data.substring(data.indexOf(',') + 1));

  return `<?xml version="1.0" encoding="UTF-8"?>\n\
      <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n\
      ${svgPath}`;
}

async function saveDiagram(drawIOEditorState, editorFacade) {
  const { newDiagram, diagramMarkdown, filename, diagramSvg } = drawIOEditorState;
  const filenameWithExt = filename.endsWith('.drawio.svg') ? filename : `${filename}.drawio.svg`;

  postMessageToDrawioEditor(drawIOEditorState, {
    action: 'spinner',
    show: true,
    messageKey: 'saving',
  });

  try {
    const uploadResults = await editorFacade.uploadDiagram({
      filename: filenameWithExt,
      diagramSvg,
    });

    if (newDiagram) {
      editorFacade.insertDiagram({ uploadResults });
    } else {
      editorFacade.updateDiagram({ diagramMarkdown, uploadResults });
    }

    createAlert({
      message: __('Diagram saved successfully.'),
      variant: VARIANT_SUCCESS,
      fadeTransition: true,
    });
    setTimeout(() => disposeDrawioEditor(drawIOEditorState), 10);
  } catch {
    postMessageToDrawioEditor(drawIOEditorState, { action: 'spinner', show: false });
    postMessageToDrawioEditor(drawIOEditorState, {
      action: 'dialog',
      titleKey: 'error',
      modified: true,
      buttonKey: 'close',
      messageKey: 'errorSavingFile',
    });
  }
}

function promptName(drawIOEditorState, name, errKey) {
  postMessageToDrawioEditor(drawIOEditorState, {
    action: 'prompt',
    titleKey: 'filename',
    okKey: 'save',
    defaultValue: name || '',
  });

  if (errKey !== null) {
    postMessageToDrawioEditor(drawIOEditorState, {
      action: 'dialog',
      titleKey: 'error',
      messageKey: errKey,
      buttonKey: 'ok',
    });
  }
}

function sendLoadDiagramMessage(drawIOEditorState) {
  postMessageToDrawioEditor(drawIOEditorState, {
    action: 'load',
    xml: drawIOEditorState.diagramSvg,
    border: 8,
    background: DIAGRAM_BACKGROUND_COLOR,
    dark: drawIOEditorState.dark,
    title: drawIOEditorState.filename,
  });
}

async function loadExistingDiagram(drawIOEditorState, editorFacade) {
  let diagram = null;

  try {
    diagram = await editorFacade.getDiagram();
  } catch (e) {
    throw new Error(__('Cannot load the diagram into the diagrams.net editor'));
  }

  if (diagram) {
    const { diagramMarkdown, filename, diagramSvg, contentType, diagramURL } = diagram;
    const resolvedURL = new URL(diagramURL, window.location.origin);
    const diagramSvgSize = new Blob([diagramSvg]).size;

    if (contentType !== 'image/svg+xml') {
      throw new Error(__('The selected image is not a valid SVG diagram'));
    }

    if (resolvedURL.origin !== window.location.origin) {
      throw new Error(__('The selected image is not an asset uploaded in the application'));
    }

    if (diagramSvgSize > DIAGRAM_MAX_SIZE) {
      throw new Error(__('The selected image is too large.'));
    }

    updateDrawioEditorState(drawIOEditorState, {
      newDiagram: false,
      filename,
      diagramMarkdown,
      diagramSvg,
    });
  } else {
    updateDrawioEditorState(drawIOEditorState, {
      newDiagram: true,
    });
  }

  sendLoadDiagramMessage(drawIOEditorState);
}

async function prepareEditor(drawIOEditorState, editorFacade) {
  const { iframe } = drawIOEditorState;

  iframe.style.cursor = 'wait';

  try {
    await loadExistingDiagram(drawIOEditorState, editorFacade);

    iframe.style.visibility = 'visible';
    iframe.style.cursor = '';
    window.scrollTo(0, 0);
  } catch (e) {
    createAlert({
      message: e.message,
      error: e,
    });
    disposeDrawioEditor(drawIOEditorState);
  }
}

function configureDrawIOEditor(drawIOEditorState) {
  postMessageToDrawioEditor(drawIOEditorState, {
    action: 'configure',
    config: {
      darkColor: DARK_BACKGROUND_COLOR,
      settingsName: 'gitlab',
    },
    colorSchemeMeta: drawIOEditorState.dark, // For transparent iframe background in dark mode
  });
  updateDrawioEditorState(drawIOEditorState, {
    initialized: true,
  });
}

function onDrawIOEditorMessage(drawIOEditorState, editorFacade, evt) {
  if (_.isNil(evt) || evt.source !== drawIOEditorState.iframe.contentWindow) {
    return;
  }

  const msg = JSON.parse(evt.data);

  if (msg.event === 'configure') {
    configureDrawIOEditor(drawIOEditorState);
  } else if (msg.event === 'init') {
    prepareEditor(drawIOEditorState, editorFacade);
  } else if (msg.event === 'exit') {
    disposeDrawioEditor(drawIOEditorState);
  } else if (msg.event === 'prompt') {
    updateDrawioEditorState(drawIOEditorState, {
      filename: msg.value,
    });

    if (!drawIOEditorState.filename) {
      promptName(drawIOEditorState, 'diagram.drawio.svg', 'filenameShort');
    } else {
      saveDiagram(drawIOEditorState, editorFacade);
    }
  } else if (msg.event === 'export') {
    updateDrawioEditorState(drawIOEditorState, {
      diagramSvg: getSvg(msg.data),
    });
    // TODO Add this to draw.io editor configuration
    sendLoadDiagramMessage(drawIOEditorState); // Save removes diagram from the editor, so we need to reload it.
    postMessageToDrawioEditor(drawIOEditorState, { action: 'status', modified: true }); // And set editor modified flag to true.
    if (!drawIOEditorState.filename) {
      promptName(drawIOEditorState, 'diagram.drawio.svg', null);
    } else {
      saveDiagram(drawIOEditorState, editorFacade);
    }
  }
}

function createEditorIFrame(drawIOEditorState) {
  const iframe = document.createElement('iframe');

  setAttributes(iframe, {
    id: DRAWIO_FRAME_ID,
    src: DRAWIO_EDITOR_URL,
    class: 'drawio-editor',
  });

  document.body.appendChild(iframe);

  setTimeout(() => {
    if (drawIOEditorState.initialized === false) {
      disposeDrawioEditor(drawIOEditorState);
      createAlert({ message: __('The diagrams.net editor could not be loaded.') });
    }
  }, DRAWIO_IFRAME_TIMEOUT);

  updateDrawioEditorState(drawIOEditorState, {
    iframe,
  });
}

function attachDrawioIFrameMessageListener(drawIOEditorState, editorFacade) {
  const evtHandler = (evt) => {
    onDrawIOEditorMessage(drawIOEditorState, editorFacade, evt);
  };

  window.addEventListener('message', evtHandler);

  // Stores a function in the editor state object that allows disposing
  // the message event listener when the editor exits.
  updateDrawioEditorState(drawIOEditorState, {
    disposeEventListener: () => {
      window.removeEventListener('message', evtHandler);
    },
  });
}

const createDrawioEditorState = ({ filename = null }) => ({
  newDiagram: true,
  filename,
  diagramSvg: null,
  diagramMarkdown: null,
  iframe: null,
  isBusy: false,
  initialized: false,
  dark: darkModeEnabled(),
  disposeEventListener: null,
});

export function launchDrawioEditor({ editorFacade, filename }) {
  const drawIOEditorState = createDrawioEditorState({ filename });

  // The execution order of these two functions matter
  attachDrawioIFrameMessageListener(drawIOEditorState, editorFacade);
  createEditorIFrame(drawIOEditorState);
}
