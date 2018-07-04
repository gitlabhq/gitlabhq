/* eslint-disable */

const initConsoleSwag = () => {
  const fontFamily = 'font-family: monospace;';
  const fontSize = 'font-size: 1.5em;';
  const earNoseColor = 'color: #e24329;';
  const eyesColor = 'color: #fc6d26;';
  const cheeksColor = 'color: #fca326;';
  const linkColor = 'color: #4b4ba3;';

  console.log("%c           +                        +", `${fontFamily} ${earNoseColor}`);
  console.log("%c          :s:                      :s:", `${fontFamily} ${earNoseColor}`);
  console.log("%c         .oso'                    'oso.", `${fontFamily} ${earNoseColor}`);
  console.log("%c         +sss+                    +sss+", `${fontFamily} ${earNoseColor}`);
  console.log("%c        :sssss-                  -sssss:", `${fontFamily} ${earNoseColor}`);
  console.log("%c       'ossssso.                .ossssso'", `${fontFamily} ${earNoseColor}`);
  console.log("%c       +sssssss+                +sssssss+", `${fontFamily} ${earNoseColor}`);
  console.log("%c      -ooooooooo-++++++++++++++-ooooooooo-", `${fontFamily} ${earNoseColor}`);
  console.log("%c     ':/%c+++++++++%cosssssssssssso%c+++++++++%c/:'", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c     -///%c+++++++++%cssssssssssss%c+++++++++%c///-", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c    .//////%c+++++++%cosssssssssso%c+++++++%c//////.", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c    :///////%c+++++++%cosssssssso%c+++++++%c///////:", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c     .:///////%c++++++%cssssssss%c++++++%c///////:.'", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c       '-://///%c+++++%cosssssso%c+++++%c/////:-'", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c          '-:////%c++++%cosssso%c++++%c////:-'", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c             .-:///%c++%cosssso%c++%c///:-.", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c               '.://%c++%cosso%c++%c//:.'", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c                  '-:/%c+%coo%c+%c/:-'", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${earNoseColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log("%c                     '-%c++%c-'", `${fontFamily} ${cheeksColor}`, `${fontFamily} ${eyesColor}`, `${fontFamily} ${cheeksColor}`);
  console.log('\n\n%cTanuki has been summoned...', `font-size: 3em; ${fontFamily} ${cheeksColor}`)
  console.log('%cWant to make this message look cooler? check out %chttps://about.gitlab.com/contributing/', `${fontSize} ${fontFamily} ${earNoseColor}`, `${fontSize} ${fontFamily} ${linkColor}`);
  console.log('%cWant to get paid for doing so? check out %chttps://about.gitlab.com/jobs/', `${fontSize} ${fontFamily} ${earNoseColor}`, `${fontSize} ${fontFamily} ${linkColor}`);
}

export default initConsoleSwag;
