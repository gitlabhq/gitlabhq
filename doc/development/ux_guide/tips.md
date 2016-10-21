# Tips

## Contents
* [SVGs](#svgs)

---

## SVGs

When exporting SVGs, be sure to follow the following guidelines:

1. Convert all strokes to outlines.
2. Use pathfinder tools to combine overlapping paths and create compound paths.
3. SVGs that are limited to one color should be exported without a fill color so the color can be set using CSS.
4. Ensure that exported SVGs have been run through an [SVG cleaner](https://github.com/RazrFalcon/SVGCleaner) to remove unused elements and attributes.

You can open your svg in a text editor to ensure that it is clean.
Incorrect files will look like this:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="16px" height="17px" viewBox="0 0 16 17" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
    <!-- Generator: Sketch 3.7.2 (28276) - http://www.bohemiancoding.com/sketch -->
    <title>Group</title>
    <desc>Created with Sketch.</desc>
    <defs></defs>
    <g id="Page-1" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g id="Group" fill="#7E7C7C">
            <path d="M15.1111,1 L0.8891,1 C0.3981,1 0.0001,1.446 0.0001,1.996 L0.0001,15.945 C0.0001,16.495 0.3981,16.941 0.8891,16.941 L15.1111,16.941 C15.6021,16.941 16.0001,16.495 16.0001,15.945 L16.0001,1.996 C16.0001,1.446 15.6021,1 15.1111,1 L15.1111,1 L15.1111,1 Z M14.0001,6.0002 L14.0001,14.949 L2.0001,14.949 L2.0001,6.0002 L14.0001,6.0002 Z M14.0001,4.0002 L14.0001,2.993 L2.0001,2.993 L2.0001,4.0002 L14.0001,4.0002 Z" id="Combined-Shape"></path>
            <polygon id="Fill-11" points="3 2.0002 5 2.0002 5 0.0002 3 0.0002"></polygon>
            <polygon id="Fill-16" points="11 2.0002 13 2.0002 13 0.0002 11 0.0002"></polygon>
            <path d="M5.37709616,11.5511984 L6.92309616,12.7821984 C7.35112915,13.123019 7.97359761,13.0565604 8.32002627,12.6330535 L10.7740263,9.63305349 C11.1237073,9.20557058 11.0606364,8.57555475 10.6331535,8.22587373 C10.2056706,7.87619272 9.57565475,7.93926361 9.22597373,8.36674651 L6.77197373,11.3667465 L8.16890384,11.2176016 L6.62290384,9.98660159 C6.19085236,9.6425813 5.56172188,9.71394467 5.21770159,10.1459962 C4.8736813,10.5780476 4.94504467,11.2071781 5.37709616,11.5511984 L5.37709616,11.5511984 Z" id="Stroke-21"></path>
        </g>
    </g>
</svg>
```

Correct file will look like this:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 17" enable-background="new 0 0 16 17"><path d="m15.1 1h-2.1v-1h-2v1h-6v-1h-2v1h-2.1c-.5 0-.9.5-.9 1v14c0 .6.4 1 .9 1h14.2c.5 0 .9-.4.9-1v-14c0-.5-.4-1-.9-1m-1.1 14h-12v-9h12v9m0-11h-12v-1h12v1"/><path d="m5.4 11.6l1.5 1.2c.4.3 1.1.3 1.4-.1l2.5-3c.3-.4.3-1.1-.1-1.4-.5-.4-1.1-.3-1.5.1l-1.8 2.2-.8-.6c-.4-.3-1.1-.3-1.4.2-.3.4-.3 1 .2 1.4"/></svg>
```

>>>
TODO: Checkout [https://github.com/svg/svgo](https://github.com/svg/svgo)
>>>