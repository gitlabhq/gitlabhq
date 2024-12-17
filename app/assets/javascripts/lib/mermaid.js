import mermaid from 'mermaid';
import { getParameterByName } from '~/lib/utils/url_utility';
import { resetServiceWorkersPublicPath } from '~/lib/utils/webpack';

const resetWebpackPublicPath = () => {
  window.gon = { relative_url_root: getParameterByName('relativeRootPath') };
  resetServiceWorkersPublicPath();
};

resetWebpackPublicPath();
const setIframeRenderedSize = (h, w) => {
  const { origin } = window.location;
  window.parent.postMessage({ h, w }, origin);
};

const drawDiagram = async (source) => {
  const element = document.getElementById('app');
  const insertSvg = (svgCode) => {
    // eslint-disable-next-line no-unsanitized/property
    element.innerHTML = svgCode;

    element.firstElementChild.removeAttribute('height');
    const { height, width } = element.firstElementChild.getBoundingClientRect();

    setIframeRenderedSize(height, width);
  };

  const { svg } = await mermaid.mermaidAPI.render('mermaid', source);
  insertSvg(svg);
};

const darkModeEnabled = () => getParameterByName('darkMode') === 'true';

const initMermaid = () => {
  let theme = 'neutral';

  if (darkModeEnabled()) {
    theme = 'dark';
  }

  mermaid.initialize({
    // mermaid core options
    mermaid: {
      startOnLoad: false,
    },
    // mermaidAPI options
    theme,
    flowchart: {
      useMaxWidth: true,
      htmlLabels: true,
    },
    secure: ['secure', 'securityLevel', 'startOnLoad', 'maxTextSize', 'htmlLabels'],
    securityLevel: 'strict',
    dompurifyConfig: {
      ADD_TAGS: ['foreignObject'],
      HTML_INTEGRATION_POINTS: { foreignobject: true },
    },
  });
};

const addListener = () => {
  window.addEventListener(
    'message',
    (event) => {
      if (event.origin !== window.location.origin) {
        return;
      }
      drawDiagram(event.data);
    },
    false,
  );
};

addListener();
initMermaid();
export default {};
